module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Use passwordless gem's session cookie to authenticate
      session_id = cookies.signed["passwordless_session_id--user"]
      if session_id
        passwordless_session = Passwordless::Session.find_by(
          id: session_id,
          authenticatable_type: "User"
        )

        if passwordless_session&.available? && passwordless_session.authenticatable
          return passwordless_session.authenticatable
        end
      end

      reject_unauthorized_connection
    end
  end
end
