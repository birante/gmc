# frozen_string_literal: true

module Vendors
  class PlansController < ApplicationController
    layout "vendor_plans"
    helper PlansHelper, VendorsHelper
    before_action :ensure_vendor_authenticated, only: [ :new, :create ]
    before_action :ensure_shop_exists, only: [ :new, :create ]
    before_action :ensure_no_subscription, only: [ :new, :create ], unless: -> { params[:upgrade].present? }

    include VendorsHelper

    def new
      # Récupérer le shop via slug si fourni, sinon le plus récent
      if params[:shop_slug].present?
        @shop = current_vendor.shops.friendly.find_by(slug: params[:shop_slug])
      else
        @shop = current_vendor.shops.order(created_at: :desc).first
      end

      # Si upgrade=true, permettre la sélection même avec une subscription existante
      @is_upgrade = params[:upgrade].present? || params[:shop_slug].present?

      # Les onglets ont été supprimés: on affiche tous les plans sur un seul écran.
      # On conserve @active_tab pour compatibilité de rendu de certaines sections legacy.
      @active_tab = "partners"
      @plans = ordered_active_plans

      # Si c'est une mise à niveau, filtrer pour ne montrer que les plans supérieurs
      if @is_upgrade && @shop&.current_subscription
        @current_plan = @shop.current_subscription.plan
        @plans = @plans.select { |plan_option| upgrade_allowed?(@current_plan, plan_option) }
      end

      @selected_plan_id = selected_plan_id_from_params
    end

    def create
      # Récupérer le shop via slug si fourni, sinon le plus récent
      if params[:shop_slug].present?
        @shop = current_vendor.shops.friendly.find_by(slug: params[:shop_slug])
      else
        @shop = current_vendor.shops.order(created_at: :desc).first
      end

      plan = Plan.find_by(id: params[:plan_id], is_active: true)

      unless plan
        @active_tab = "partners"
        @plans = ordered_active_plans
        flash.now[:alert] = t("vendors.plans.invalid_plan")
        render :new, status: :unprocessable_entity
        return
      end

      unless plan.purchasable_online?
        redirect_to new_vendors_plan_path(plan_context_params),
                    alert: t("vendors.plans.custom_plan_contact_required", phone: Plan.support_contact_phone)
        return
      end

      # Determiner si c'est un upgrade
      @is_upgrade = params[:upgrade].present? || @shop.current_subscription.present?

      if @is_upgrade && @shop.current_subscription.present? && !upgrade_allowed?(@shop.current_subscription.plan, plan)
        @active_tab = "partners"
        @plans = ordered_active_plans.select { |plan_option| upgrade_allowed?(@shop.current_subscription.plan, plan_option) }
        flash.now[:alert] = t("vendors.plans.invalid_plan")
        render :new, status: :unprocessable_entity
        return
      end

      # Verifier si le plan necessite un paiement
      if plan_requires_payment?(plan)
        # Passer par PayDunya pour le paiement (nouvelle souscription OU upgrade)
        handle_subscription_payment(plan, is_upgrade: @is_upgrade)
      else
        # Plan gratuit (ACCESS)
        if @is_upgrade
          # Upgrade vers un plan gratuit (rare mais possible)
          service = Vendors::UpgradePlanService.new(shop: @shop, new_plan: plan)
          result = service.call

          if result.success?
            Rails.logger.info("[Vendors::PlansController] Plan mis a niveau (gratuit) - shop_id: #{@shop.id}, plan: #{plan.code}")
            redirect_to url_with_shop(vendors_dashboard_path, @shop),
                        notice: t("vendors.plans.upgrade_success", plan_name: plan.name)
          else
            flash.now[:alert] = result.errors.join(", ")
            @plans = Plan.active.standard.order(:id)
            render :new, status: :unprocessable_entity
          end
        else
          # Nouvelle subscription gratuite
          subscription = Subscription.create!(
            shop: @shop,
            plan: plan,
            status: "active",
            started_at: Time.current,
            ends_at: 1.year.from_now
          )

          Rails.logger.info("[Vendors::PlansController] Plan gratuit selectionne - shop_id: #{@shop.id}, plan: #{plan.code}")

          redirect_to url_with_shop(vendors_dashboard_path, @shop),
                      notice: t("vendors.plans.subscription_created", plan_name: plan.name)
        end
      end
    end

    private

    def ensure_vendor_authenticated
      unless current_vendor
        redirect_to new_vendors_session_path, alert: t("vendors.authentication.must_be_logged_in_with_period")
      end
    end

    def ensure_shop_exists
      unless current_vendor&.shops&.any?
        redirect_to new_vendors_shop_path, alert: t("vendors.plans.shop_required")
      end
    end

    def ensure_no_subscription
      shop = current_vendor&.shops&.order(created_at: :desc)&.first
      if shop&.current_subscription
        redirect_to url_with_shop(vendors_dashboard_path, shop),
                    notice: t("vendors.plans.already_subscribed")
      end
    end

    def plan_requires_payment?(plan)
      # Aucun paiement en ligne si le prix du plan est 0 (ACCESS, promos, etc.)
      plan.price.to_f.positive?
    end

    def handle_subscription_payment(plan, is_upgrade: false)
      # Verifier que le withdraw_mode est fourni
      unless params[:withdraw_mode].present?
        Rails.logger.warn("[Vendors::PlansController] Aucun mode de paiement selectionne")
        redirect_to new_vendors_plan_path(plan_id: plan.id, upgrade: is_upgrade || nil), alert: "Veuillez selectionner un mode de paiement."
        return
      end

      # Recuperer la methode de paiement active correspondant au withdraw_mode selectionne
      payment_method = resolve_subscription_payment_method(params[:withdraw_mode])

      unless payment_method
        Rails.logger.error("[Vendors::PlansController] Mode de paiement invalide ou inactif: #{params[:withdraw_mode]}")
        redirect_to new_vendors_plan_path(upgrade: is_upgrade || nil), alert: "Le moyen de paiement selectionne n'est pas disponible."
        return
      end

      # Calculer le montant du plan (pour upgrade, on pourrait calculer un prorata)
      amount = calculate_plan_amount(plan, is_upgrade: is_upgrade)

      # Creer le paiement d'abonnement
      subscription_payment = @shop.subscription_payments.build(
        plan: plan,
        payment_method: payment_method,
        amount: amount,
        status: "pending",
        withdraw_mode: params[:withdraw_mode],
        payment_type: is_upgrade ? "UPGRADE" : "PAR"
      )

      unless subscription_payment.save
        Rails.logger.error("[Vendors::PlansController] Erreur creation paiement subscription - #{subscription_payment.errors.full_messages.join(', ')}")
        redirect_to new_vendors_plan_path(plan_id: plan.id), alert: "Erreur lors de la création du paiement."
        return
      end

      # Initialiser le paiement Paydunya (utiliser le service HTTP comme pour les commandes clients)
      service = PaymentServices::SubscriptionPaydunyaHttpService.new(
        subscription_payment: subscription_payment,
        shop: @shop,
        plan: plan
      )

      result = service.create_checkout_invoice

      if result.success?
        Rails.logger.info("[Vendors::PlansController] Invoice Paydunya creee - payment_id: #{subscription_payment.id}, withdraw_mode: #{subscription_payment.withdraw_mode}")
        # Afficher une page de transition avant la redirection vers Paydunya
        @redirect_url = result.redirect_url
        render template: "paydunya_callbacks/redirecting", layout: false
      else
        Rails.logger.error("[Vendors::PlansController] Erreur creation invoice Paydunya - #{result.errors.join(', ')}")
        subscription_payment.update(status: "failed", failure_reason: result.errors.join(", "))
        redirect_to new_vendors_plan_path(plan_id: plan.id), alert: "Erreur lors de l'initialisation du paiement: #{result.errors.first}"
      end
    end

    def resolve_subscription_payment_method(withdraw_mode)
      code = {
        "wave-senegal" => "wave_sn",
        "orange-money-senegal" => "orange_money_sn",
        "free-money-senegal" => "free_money_sn",
        "expresso-senegal" => "expresso_sn"
      }[withdraw_mode.to_s]

      return nil if code.blank?

      PaymentMethod.active.find_by(code: code)
    end

    def calculate_plan_amount(plan, is_upgrade: false)
      # Pour un upgrade, on pourrait calculer un prorata
      # Pour l'instant, on facture le prix complet du nouveau plan
      if is_upgrade && @shop.current_subscription
        # Option: calculer le prorata (jours restants sur l'ancien plan)
        # current_sub = @shop.current_subscription
        # days_remaining = (current_sub.ends_at - Time.current).to_i / 1.day
        # prorata_credit = (current_sub.plan.price.to_f / 365) * days_remaining
        # return [plan.price.to_f - prorata_credit, 0].max

        # Pour l'instant, facturer le prix complet
        plan.price.to_f
      else
        plan.price.to_f
      end
    end

    def ordered_active_plans
      Plan.active.order(Arel.sql("CASE code WHEN 'ACCESS' THEN 1 WHEN 'STARTER' THEN 2 WHEN 'BUSINESS' THEN 3 WHEN 'PARTNER' THEN 4 ELSE 99 END"), :id)
    end

    def selected_plan_id_from_params
      selected_plan = @plans.find { |plan| plan.id == params[:plan_id].to_i }
      return unless selected_plan&.purchasable_online?

      selected_plan.id
    end

    def plan_context_params
      {
        upgrade: params[:upgrade].presence,
        shop_slug: params[:shop_slug].presence
      }.compact
    end

    def upgrade_allowed?(current_plan, new_plan)
      plan_rank(new_plan) > plan_rank(current_plan)
    end

    def plan_rank(plan)
      {
        "ACCESS" => 1,
        "STARTER" => 2,
        "BUSINESS" => 3,
        "PARTNER" => 4
      }.fetch(plan&.code.to_s.upcase, 0)
    end

    # current_vendor est déjà défini dans ApplicationController via Current.session
    # qui supporte test_vendor_id via le module Authentication
  end
end
