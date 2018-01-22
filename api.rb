module Api

  extend ActiveSupport::Concern

  def self.included(base)
    base.class_eval do
      def self.all(options={})
        object = self.to_s.underscore.downcase

        if options.present?
          option_string = '?' + options.map{|key, value| [key, value].join('=')}.join('&')
        else
          option_string = ''
        end

        response = HTTParty.get("#{ENV["API_PATH"]}/#{object.pluralize}.json#{option_string}")

        return response[object.pluralize].map{|r| self.new(r)}
      end

      def self.find(id)
        object   = self.to_s.underscore.downcase
        response = HTTParty.get("#{ENV["API_PATH"]}/#{object.pluralize}/#{id}.json")

        return self.new(response[object])
      end
    end
  end

  def save
    object = self.class.to_s.downcase

    response = HTTParty.post("#{ENV["API_PATH"]}/#{object.pluralize}.json",
      body: {
        object.to_sym => self
      }.to_json, headers: {
      'Content-Type' => 'application/json'
    })

    if response["status"] == 201
      return self.class.new(response[object].merge(status: 201))
    else
      return Errors.new(response.merge(status: 422))
    end
  end

  def update(params)
    object = self.class.to_s.underscore.downcase

    response = HTTParty.put("#{ENV["API_PATH"]}/#{object.pluralize}/#{self.id}.json", body: {
      object.to_sym => params
    }.to_json, headers: {
      'Content-Type' => 'application/json'
    })

    if response["status"] == 202
      return self.class.new(response[object])
    else
      return false
    end
  end

  def destroy(params=nil)
    object = self.class.to_s.underscore.downcase

    response = HTTParty.delete("#{ENV["API_PATH"]}/#{object.pluralize}/#{self.id}.json", body: {
      object.to_sym => params
    }.to_json, headers: {
      'Content-Type' => 'application/json'
    })

    if response["status"] == 203
      return true
    else
      return false
    end
  end

end
