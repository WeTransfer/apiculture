require 'builder'
# Generates Markdown/HTML documentation about a single API action.
#
# Formats route parameters and request/QS parameters as a neat HTML
# table, listing types, requirements and descriptions.
#
# Is used by AppDocumentation to compile a document on the entire app's API
# structure in one go.
class Apiculture::MethodDocumentation
  def initialize(action_definition, mountpoint = '')
    @definition = action_definition
    @mountpoint = mountpoint
  end

  # Compose a Markdown definition of the action
  def to_markdown
    m = MDBuf.new
    m << "## #{@definition.http_verb.upcase} #{@mountpoint}#{@definition.path}"
    m << @definition.description
    m << route_parameters_table
    m << request_parameters_table
    m << possible_responses_table

    m.to_s
  end

  # Compose an HTML string by converting the result of +to_markdown+
  def to_html_fragment
    require 'rdiscount'
    RDiscount.new(to_markdown).to_html
  end

  private

  class StringBuf #:nodoc:
    def initialize; @blocks = []; end
    def <<(block); @blocks << block.to_s; self; end
    def to_s; @blocks.join; end
  end

  class MDBuf < StringBuf  #:nodoc:
    def to_s; @blocks.join("\n\n"); end
  end

  def _route_parameters_table
    return '' unless @definition.defines_route_params?

    m = MDBuf.new
    b = StringBuf.new
    m << '### URL parameters'

    html = Builder::XmlMarkup.new(:target => b)
    html.table(class: 'apiculture-table') do
      html.tr do
        html.th 'Name'
        html.th 'Description'
      end

      @definition.route_parameters.each do | param |
        html.tr do
          html.td { html.tt(':%s' % param.name) }
          html.td(param.description)
        end
      end
    end
    m << b.to_s
  end

  def body_example(for_response_definition)
    if for_response_definition.no_body?
      '(empty)'
    else
      begin
        JSON.pretty_generate(for_response_definition.jsonable_object_example)
      rescue JSON::GeneratorError
        # pretty_generate refuses to generate scalars
        # it wants objects or arrays. For bare JSON values .dump will do
        JSON.dump(for_response_definition.jsonable_object_example)
      end
    end
  end

  def possible_responses_table
    return '' unless @definition.defines_responses?

    m = MDBuf.new
    b = StringBuf.new
    m << '### Possible responses'

    html = Builder::XmlMarkup.new(:target => b)
    html.table(class: 'apiculture-table') do
      html.tr do
        html.th('HTTP status code')
        html.th('What happened')
        html.th('Example response body')
      end

      @definition.responses.each do | resp |
        html.tr do
          html.td { html.b(resp.http_status_code) }
          html.td resp.description
          html.td { html.pre { html.code(body_example(resp)) }}
        end
      end
    end

    m << b.to_s
  end

  def request_parameters_table
    return '' unless @definition.defines_request_params?
    m = MDBuf.new
    m << '### Request parameters'
    m << parameters_table(@definition.parameters).to_s
  end

  def route_parameters_table
    return '' unless @definition.defines_route_params?
    m = MDBuf.new
    m << '### URL parameters'
    m << parameters_table(@definition.route_parameters).to_s
  end


  private
  def parameters_table(parameters)
    b = StringBuf.new
    html = Builder::XmlMarkup.new(:target => b)
    html.table(class: 'apiculture-table') do
      html.tr do
        html.th 'Name'
        html.th 'Required'
        html.th 'Type after cast'
        html.th 'Description'
      end

      parameters.each do | param |
        html.tr do
          html.td { html.tt(param.name.to_s) }
          html.td(param.required ? 'Yes' : 'No')
          html.td(param.matchable.inspect)
          html.td(param.description.to_s)
        end
      end
    end
    b
  end
end
