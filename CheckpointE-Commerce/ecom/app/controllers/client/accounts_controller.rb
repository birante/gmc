module Client
  class AccountsController < BaseController
    def show
      @user = current_user
    end

    def edit
      @user = current_user
    end

    def update
      @user = current_user

      # Si le mot de passe est vide, retirer les champs password des paramètres
      params_to_update = account_params
      if params_to_update[:password].blank?
        params_to_update = params_to_update.except(:password, :password_confirmation)
      end

      if @user.update(params_to_update)
        redirect_to client_account_path, notice: "Vos informations ont été mises à jour avec succès."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def account_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :email_address,
        :phone_number,
        :country_code,
        :password,
        :password_confirmation
      )
    end
  end
end
