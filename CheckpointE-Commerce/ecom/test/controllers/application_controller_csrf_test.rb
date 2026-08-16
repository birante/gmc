# frozen_string_literal: true

require "test_helper"

# Couvre le rescue global de ActionController::InvalidAuthenticityToken défini dans
# ApplicationController : on doit reset la session côté cookie, préserver le panier
# invité, et rediriger gentiment plutôt que de cracher un 422 brut.
class ApplicationControllerCsrfTest < ActionDispatch::IntegrationTest
  setup do
    # La suite désactive la protection CSRF par défaut ; on la rallume ici pour
    # déclencher le chemin de rescue qu'on veut tester.
    @csrf_was = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @csrf_was
  end

  test "POST sans token CSRF redirige proprement avec message au lieu d'un 422 brut" do
    # On poste sur le login client sans token CSRF : doit déclencher le rescue.
    post client_session_path, params: { phone_number: "770000000", country_code: "SN", password: "x" }

    assert_response :redirect
    assert_match(/session a expiré/i, flash[:alert].to_s)
  end

  test "le rescue préserve le panier invité après reset_session" do
    # 1) Déclencher la création d'un panier invité (Client::CartsController#show le crée).
    get "/fr/client/cart", params: { frame: "sheet" }
    follow_redirect! while response.redirect?

    guest_cart_id = session[:guest_cart_id]
    assert guest_cart_id.present?, "Pré-condition : un panier invité doit être créé en session"

    # 2) Tenter un POST CSRF-invalide.
    post "/fr/client/session", params: { phone_number: "770000000", country_code: "SN", password: "x" }
    assert_response :redirect

    # 3) Le panier invité doit avoir survécu au reset_session.
    assert_equal guest_cart_id, session[:guest_cart_id],
                 "Le guest_cart_id doit être préservé à travers le rescue CSRF"
  end

  test "le rescue préserve la locale après reset_session" do
    # Passer par une URL locale-fr pour poser session[:locale]
    get "/fr"
    follow_redirect! while response.redirect?
    assert_equal "fr", session[:locale].to_s, "Pré-condition : la locale fr doit être posée"

    post "/fr/client/session", params: { phone_number: "770000000", country_code: "SN", password: "x" }

    assert_response :redirect
    assert_equal "fr", session[:locale].to_s, "La locale doit survivre au reset CSRF"
  end
end
