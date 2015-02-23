module TrafficSpy
  class Server < Sinatra::Base

    get "/" do
      erb :index
    end

    post "/sources" do
      identifier_generator = IdentifierGenerator.call(params)
      status identifier_generator.status
      body   identifier_generator.message
    end

    post "/sources/:identifier/data" do |identifier|
      payload_generator = PayloadGenerator.call(params[:payload], identifier)
      status payload_generator.status
      body   payload_generator.message
    end

    get "/sources/:identifier" do |identifier|
      source = Source.find_by(identifier: identifier)
      if source
        @payloads       = source.payloads
        @urls           = Url.all
        @relative_paths = Payload.relative_url_paths
        @user_agents    = PayloadUserAgent.all
        @resolutions    = Resolution.all
        @response_times = Payload.response_times
        erb :app_details
      else
        erb :unregistered_user
      end
    end

    get '/sources/:identifier/events' do |identifier|
      # need to check if :identifier has any events
      @source = Source.find_by(identifier: identifier)

      if @source and !@source.payloads.empty?
        @events_by_source = @source.payloads.map {|payload| payload.event }
        @events = @events_by_source.inject(Hash.new(0)) {|sum,event| sum[event]+=1; sum }.sort_by {|k,v| -v}
        erb :event_index
      else
        erb :event_index_error 
      end
    end

    get '/sources/:indentifier/events/:EVENTNAME' do |identifier, event_name|
      @source = Source.find_by(identifier: identifier)
      @all_events = @source.payloads.map {|payload| payload.event }
      @event = @all_events.find {|event| event_name == event.name }
      @event_count = @event.payloads.count
      @hours_breakdown = @event.hour_by_hour_breakdown
       
         # hour_by_hour_breakdown.each {|k,v| p "#{k}:#{v}"}
        erb :event_details
      
    end

    get "/sources/:identifier/urls/*" do
      root_url = Source.find_by(identifier: params[:identifier]).root_url
      @created_address = Url.create_url(root_url, params[:splat].join("/"))
      if !Url.exists?(address: @created_address)
        erb :url_error
        status 404
      else
        @longest_response  = Url.longest_response(@created_address)
        @shortest_response = Url.shortest_response(@created_address)
        @average_response  = Url.average_response(@created_address)
        @http_verbs        = Url.http_verbs(@created_address)
        @pop_referrer      = Url.popular_referrer(@created_address)
        @pop_agent         = Url.popular_user_agent(@created_address)
        erb :url_statistics
      end
    end

    not_found do
      erb :error
    end
  end
end
