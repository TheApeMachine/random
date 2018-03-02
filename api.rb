module Api

  extend ActiveSupport::Concern

  def self.included(base)
    base.class_eval do
      def self.build_request(object, options={}, body={})
        object    = object.to_s.underscore.downcase
        base_path = "#{ENV["API_PATH"]}/#{object.pluralize}"

        if options.present?
          option_string = '?' + options.select{
            |key, value| key.to_s != 'id'
          }.map{
            |key, value| [key, value].join('=')
          }.join('&')
        else
          option_string = ''
        end

        if options[:id].present?
          url = "#{base_path}/#{options[:id]}.json#{option_string}"
        else
          url = "#{base_path}.json#{option_string}"
        end

        if body.present?
          result = HTTParty.put(url, body: {
            object.to_sym => body
          }.to_json, headers: {
            'Content-Type' => 'application/json'
          })
        else
          result = HTTParty.get(url)
        end

        return {
          object: object,
          result: result
        }
      end

      def self.all(options={})
        response = build_request(self, options)

        return response[:result][
          response[:object].pluralize
        ].map{|r| self.new(r)}
      end

      def self.find(id)
        response = build_request(self, {id: id})
        return self.new(response[:result][response[:object]])
      end
    end
  end

  def save
    response = self.class.build_request(self.class, {}, self)

    if response["status"] == 201
      return self.class.new(response[object].merge(status: 201))
    else
      return Errors.new(response.merge(status: 422))
    end
  end

  def update(params)
    response = self.class.build_request(self.class, {id: self.id}, params)

    if response["status"] == 202
      return self.class.new(response[object])
    else
      return false
    end
  end

  def destroy(params=nil)
    response = self.class.build_request(self.class, {id: self.id}, params)

    if response["status"] == 203
      return true
    else
      return false
    end
  end

end
