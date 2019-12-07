module InertiaRails
  def self.configure
    yield(Configuration)
  end

  def self.version
    Configuration.evaluated_version
  end

  def self.layout
    Configuration.layout
  end

  private

  module Configuration
    mattr_accessor(:layout) { 'application' }
    mattr_accessor(:version) { nil }

    def self.evaluated_version
      self.version.respond_to?(:call) ? self.version.call : self.version
    end
  end
end
