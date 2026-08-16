# frozen_string_literal: true

Rails.application.configure do
  config.mission_control.jobs.base_controller_class = "MissionControl::BaseController"
end
