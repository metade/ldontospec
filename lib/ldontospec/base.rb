require 'pp'
module LDOntoSpec
  
  class Scope
    PROTECTED = ['@ontology', '@authors', '@version', '@namespaces']
    def initialize(object)
      @staticmatic = object.instance_variable_get('@staticmatic')
    end
    
    def instance_variable_set(name, value)
      # don't reset special variables
      super unless (PROTECTED.include?(name) and instance_variable_get(name))
    end
  end
  
  class Base < StaticMatic::Base
    attr_accessor :ontology_uri, :ontology_prefix
     
    def initialize(base_dir, configuration = Configuration.new)
      super
      @templates_dir = File.join(File.dirname(__FILE__), 'templates')
      @settings_path = File.join(@base_dir, 'settings.yml')
      @scope = Scope.new(@scope)
    end
    
    def setup
      super
      setup_ontology(@ontology_uri, @ontology_prefix)
    end
    
    def build
       build_ontology       
       super
    end
    
    def preview
       build_ontology       
       super
    end
    
    # broken in staticmatic?
    def generate_html_from_template_source(source, options = {})
      html = Haml::Engine.new(source, options)
      locals = options[:locals] || {}
      html.render(@scope, locals) { yield }
    end
    
    def generate_partial(name, options = {})
      begin
        super
      rescue StaticMatic::Error => e
        generate_ldontospec_partial(name, options) if e.message =~ /Partial not found/
      end
    end

    def generate_ldontospec_partial(name, options = {})
      partial_path = File.join(@templates_dir, 'partials', "#{name}.haml")
      if File.exists?(partial_path)
        partial_rel_path = partial_path.gsub(/\/+/, '/')
        @current_file_stack.unshift(partial_rel_path)
        begin
          generate_html_from_template_source(File.read(partial_path), options)
        rescue Haml::Error => haml_error
          raise StaticMatic::Error.new(haml_error.haml_line, "Partial: #{partial_rel_path[0,partial_rel_path.length-5]}", haml_error.message)
        ensure
          @current_file_stack.shift
        end
      else
        raise StaticMatic::Error.new("", name, "Partial not found")
      end      
    end
    
    protected
    
    def build_ontology
      config = YAML.load_file(@settings_path)
      
      triples_cache = File.join(@base_dir, 'cache.sqlite3')
      adapter = ConnectionPool.add_data_source(:type => :reddy, :location => triples_cache)
      
      ontology = OWL::Ontology.new(config[:uri])
      namespaces = config[:namespaces]
      namespaces.keys.each { |key| Namespace.register key, namespaces[key] }
      
      # Register some standard ontologies
      Namespace.register 'dc', 'http://purl.org/dc/elements/1.1/'
      Namespace.register 'dcterms', 'http://purl.org/dc/terms/'
      Namespace.register 'foaf', 'http://xmlns.com/foaf/0.1/'
      
      ObjectManager.construct_classes
      namespaces.each_key { |key| namespaces[key] = RDFS::Resource.new(namespaces[key]) }
      
      authors = [ ontology.foaf::maker, ontology.dc::contributor ].flatten.compact.uniq
      authors.flatten!
      
      if ontology.dc::date =~ %r[Date: (\d+/\d+/\d+) \d+:\d+:\d+ ]
        date = $1
        version = date.gsub('/','-') unless date.blank?
      else
        version = Date.today.strftime('%Y-%m-%d')
      end
      
      @scope.instance_variable_set("@ontology", ontology)
      @scope.instance_variable_set("@authors", authors)
      @scope.instance_variable_set("@version", version)
      @scope.instance_variable_set("@namespaces", namespaces)
    end
    
    def setup_ontology(uri, prefix)      
      triples_cache = File.join(@base_dir, 'cache.sqlite3')
      adapter = ConnectionPool.add_data_source(:type => :reddy, :location => triples_cache)
      # FIXME: remove this once Rena supports more RDF
      adapter_rapper = ConnectionPool.add_data_source(:type => :fetching, :location => triples_cache)
      
      puts "Fetching Ontology: #{uri}"
      adapter.fetch(uri)
      
      Namespace.register prefix, uri
      Namespace.register 'foaf', 'http://xmlns.com/foaf/0.1/'
      Namespace.register 'dc', 'http://purl.org/dc/elements/1.1/'      
      ObjectManager.construct_classes
      
      rules = RuleBase.new('MyRuleBase') {
        rule "unionOf" do
          condition :s, :p, :o
          condition :o, OWL::unionOf, :list
          condition :list, RDF::first, :thing
          
          conclusion :s, :p, :thing
        end
        rule "unionOf-rest" do
          condition :s, :p, :o
          condition :o, OWL::unionOf, :list
          # FIXME: what if there is a longer list???
          condition :list, RDF::rest, :rest 
          condition :rest, RDF::first, :thing
          
          conclusion :s, :p, :thing
        end
      }
      
      puts "Applying inference rules"
      re = RuleEngine.new
      re.rule_bases << RuleEngine::RDFSRuleBase
      re.rule_bases << RuleEngine::OWLRuleBase
      re.rule_bases << rules
      while re.process_rules; end     
      
      # Cache namespaced ontologies
      adapter.namespaces.values.each do |ns|
        next if ns==uri
        puts "Fetching linked data #{ns}"
        adapter_rapper.fetch ns
      end
      
      # Cache authors
      ontology = RDFS::Resource.new(uri)
      [ ontology.foaf::maker, ontology.dc::contributor ].flatten.compact.uniq.each do |author|
        adapter_rapper.fetch author.uri
      end
      
      settings = {
        :uri => uri,
        :prefix => prefix,
        :namespaces => adapter.namespaces
      }
      File.open(@settings_path, 'w') { |f| f.puts(settings.to_yaml) }
    end
    
  end
end
