require_relative "inertia_rails"

module InertiaRails
  class Renderer
    attr_reader :component, :view_data

    def initialize(component, controller, request, response, render_method, props:, view_data:, layout: nil)
      @component = component
      @controller = controller
      @request = request
      @response = response
      @render_method = render_method
      @props = props || {}
      @view_data = view_data || {}
      @layout = layout
    end

    def render
      if @request.headers['X-Inertia']
        @response.set_header('Vary', 'Accept')
        @response.set_header('X-Inertia', 'true')
        @render_method.call json: page, status: @response.status, content_type: Mime[:json]
      else
        @render_method.call template: 'inertia', layout: layout, locals: (view_data).merge({page: page})
      end
    end

    private

    def layout
      case @layout
      when Proc
        # Passed as a controller-level set layout, or none set at all
        @layout.call(@controller.lookup_context) || ::InertiaRails.layout
      else
        @layout
      end
    end

    def props
      _props = ::InertiaRails.shared_data(@controller).merge(@props).select do |key, prop|
        if rendering_partial_component?
          key.in? partial_keys
        else
          !prop.is_a?(InertiaRails::Lazy)
        end
      end

      deep_transform_values(_props, lambda {|prop| prop.respond_to?(:call) ? @controller.instance_exec(&prop) : prop })
    end

    def page
      {
        component: component,
        props: props,
        url: @request.original_fullpath,
        version: ::InertiaRails.version,
      }
    end

    def deep_transform_values(hash, proc)
      return proc.call(hash) unless hash.is_a? Hash

      hash.transform_values {|value| deep_transform_values(value, proc)}
    end

    def partial_keys
      (@request.headers['X-Inertia-Partial-Data'] || '').split(',').compact.map(&:to_sym)
    end

    def rendering_partial_component?
      @request.inertia_partial? && @request.headers['X-Inertia-Partial-Component'] == component
    end
  end
end
