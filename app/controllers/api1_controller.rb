# frozen_string_literal: true

class Api1Controller < ActionController::API
  include ActionController::MimeResponds
  include ActionController::Caching

  helper ApiHelper
  helper ApplicationHelper

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :incorrect_request
  rescue_from ActionController::InvalidAuthenticityToken,
              with: :invalid_auth_token

  prepend_before_action :skip_trackable


  private

  def incorrect_request
    render json: { success: false,
                   error: I18n.t('api.errors.unprocessable_entity') },
           status: :unprocessable_entity
  end

  # So we can use Pundit policies for api_users
  def invalid_auth_token
    render json: { success: false, error: I18n.t('api.errors.unauthorized') },
           status: :unauthorized
  end

  def not_found
    render json: { success: false, error: I18n.t('api.errors.not_found') },
           status: :not_found
  end


  def skip_trackable
    request.env['devise.skip_trackable'] = true
  end

  def user_agent
    request.user_agent.downcase.include?('okhttp') ? 'android' : 'apple'
  end
end
