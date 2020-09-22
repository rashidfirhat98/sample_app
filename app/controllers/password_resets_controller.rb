class PasswordResetsController < ApplicationController
  before_action :get_user, :valid_user, :check_expiration, only: %i(edit update)
  
  def new; end

  def edit; end

  def create
    @user = User.find_by email: params[:password_reset][:email].downcase

    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash.now[:danger] = "Email address not found"
      render :new
    end
  end

  def update
    if user_params[:password].blank?
      @user.errors.add(:password, "can't be empty")
    elsif @user.update user_params
      log_in @user
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      flash[:danger] = "Password unchanged"
      render :edit
    end
  end

  private
  
  def get_user
    @user = User.find_by email: params[:email]

    return if @user

    flash[:danger] = "User not found"
    redirect_to root_url
  end

  def valid_user
    return if @user && @user.activated? && @user.authenticated?(:reset, params[:id])
    redirect_to root_url
  end

  def user_params
    params.require(:user).permit :password, :password_confirmation
  end

  def check_expiration
    return unless @user.password_reset_expired?
    flash[:danger] = "Password reset has expired."
    redirect_to new_password_reset_url
  end
end
