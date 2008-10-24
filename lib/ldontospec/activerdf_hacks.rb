RDFS::Resource.class_eval do
  define_method(:title) do
    label = self.rdfs::label
    label = self.dc::title if label.nil?
    label = self.dcterms::title if label.nil?
    return (label.nil? ? '' : label)
  end
  
  define_method(:search_for_property) do |property|
    results = Query.new.select(:s).where(self, property, :s).execute
    results.uniq!
    return results.delete_if { |r| r.uri =~ %r[http://www.activerdf.org/bnode/] }
  end
  
  define_method(:search_for_property_of) do |property|
    results = Query.new.select(:s).where(:s, property, self).execute
    results.uniq!
    return results.delete_if { |r| r.uri =~ %r[http://www.activerdf.org/bnode/] }    
  end
end

OWL::Ontology.class_eval do
  define_method(:classes) do
    all_classes = OWL::Class.find_all
    return all_classes.find_all { |c| c.uri.index(self.uri) }.sort
  end

  define_method(:properties) do
    all_properties = OWL::ObjectProperty.find_all
    all_properties << OWL::DatatypeProperty.find_all
    all_properties << OWL::TransitiveProperty.find_all
    all_properties.flatten!.uniq!
    return all_properties.find_all { |p| p.uri.index(self.uri) }.sort
  end
end

OWL::Class.class_eval do 
  define_method(:funky_properties) do
    properties = {
      'subClassOf' => self.search_for_property(RDFS::subClassOf),
      'inDomainOf' => self.search_for_property_of(RDFS::domain),
      'inRangeOf' =>  self.search_for_property_of(RDFS::range)
    }
    return properties.delete_if {|prop, classes | classes.nil? or classes.empty? }
  end
end

[OWL::ObjectProperty, OWL::TransitiveProperty, OWL::DatatypeProperty].each do |c|
  c.class_eval do
    define_method(:funky_properties) do
      properties = {
        'subPropertyOf' => self.search_for_property(RDFS::subPropertyOf),
        'domain' =>self.search_for_property(RDFS::domain),
        'range' => self.search_for_property(RDFS::range),
      }
      return properties.delete_if {|prop, classes | classes.nil? or classes.empty? }
    end
  end
end