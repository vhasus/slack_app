def log_msg(logger, message, success)
  logger.info("#{message} %s" % [  success ? "successfull" : "failed"])
end

get '/authorize' do
  if code = request.params["code"]
    state = request.params["state"]
    if state == USER_STATE
      key, email = SLACK_AUTH_CLIENT.auth_user(code)
      USERS_REPOSITORY.register(key, email)
      if key && email && data = PENDING_AUTH.dequeue(key)
        if data
          logger.info("Replacing ephemeral message")
          ["subtype", "type", "fallback", "ts", "bot_id"].each do |data_key|
            data[:message].delete(data_key)
          end
          data[:message]["attachments"].each{|msg| msg.delete("id")}
          logger.info("Original message is being sent over post is : #{data[:message]}")
          response = HTTParty.post(data[:url], body: JSON.dump(data[:message]), headers: {"Content-Type" => "application/json"})
          logger.info(response)
        end
      end
      log_msg(logger, "User Authorization", USERS_REPOSITORY.registered?(key))
    else
      token = SLACK_AUTH_CLIENT.auth(code)
      log_msg(logger, "App Authorization", !token.nil?)
    end
  end
  ""
end
