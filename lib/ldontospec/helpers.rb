module LDOntoSpec
  module Helpers
    def link_to_ontology_rdf()
      %[<link rel="meta" type="application/rdf+xml" title="#{@ontology.title} RDF Representation" href="#{@ontology.uri}" />]
    end
    
    def name_for_resource(resource)
      name = resource.localname
      name << " - #{resource.vs::term_status }" if Namespace.abbreviations.include? :vs
      name
    end
    
    def comments_paragraphs(resource)
      return '' if resource.rdfs::comment.nil?
      comments = resource.rdfs::comment.map { |c| c.strip }.find_all { |c| !c.blank? }
      comments.map { |c| "<p>#{c}</p>" }.join("\n")
    end
    
    def link_to_author(author) 
      if (author.nil?)
        ''
      elsif (author and author.foaf::name and author.foaf::homepage)
        link_to author.foaf::name, author.foaf::homepage.uri
      elsif (author and author.foaf::name)
        link_to author.foaf::name, author.uri
      else
        link_to author.uri, author.uri
      end
    end
    
    def link_to_term(term)
      prefix = @namespaces.keys.find { |k| k if (term.uri.index(@namespaces[k].uri)==0) }
      if term.uri.index(@ontology.uri)==0
        link = "##{term.localname}"
      else
        link = term.uri
      end    
      link_to("#{prefix}:#{term.localname}", link)
    end
    
    def setup_ontology(uri, prefix)
      if ConnectionPool.adapters.empty?
        ConnectionPool.add_data_source(
          :type => :fetching,
          :location => "#{prefix}.sqlite3") 
      end
      ldontospec = LDOntoSpec.new(prefix, uri)

      @namespaces = ldontospec.namespaces
      @namespaces[prefix] = uri      
      @namespaces.keys.each { |key| Namespace.register key, @namespaces[key] }
      ObjectManager.construct_classes    

      @namespaces.each_key { |key| @namespaces[key] = RDFS::Resource.new(@namespaces[key]) }
      @ontology = OWL::Ontology.new(ldontospec.ontology_uri)

      @authors = [ @ontology.foaf::maker ]
      @authors << [ @ontology.dc::contributor ]
      @authors.flatten!
      @authors.each { |author| ConnectionPool.read_adapters.first.fetch author.uri }

      @version = Date.today.strftime('%Y-%m-%d')
      if @ontology.dc::date =~ %r[Date: (\d+/\d+/\d+) \d+:\d+:\d+ ]
        date = $1
        @version = date.gsub('/','-') unless date.blank?
      end
    end
  end
end