require 'digest'
require 'json'

class PayloadGenerator
  attr_reader :status, :message
  def initialize(status, message)
    @status  = status
    @message = message
  end

  def self.call(params, identifier)
    source = Source.find_by(identifier: identifier)
    return PayloadGenerator.new(403, "not registered") unless source

    if params.nil? || JSON.parse(params).empty?
      PayloadGenerator.new(400, "missing payload")
    elsif Payload.find_by(digest: Digest::SHA2.hexdigest(params))
      PayloadGenerator.new(403, "duplicate request")
    else
      payload_params = JSON.parse(params).symbolize_keys
      payload = Payload.create({
          url_id: Url.find_or_create_by(address: payload_params[:url]).id,
          })
      source.payloads << payload
      PayloadGenerator.new(200, "payload successful")
    end
  end
end
