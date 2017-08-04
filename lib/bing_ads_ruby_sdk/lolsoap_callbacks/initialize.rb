require 'bing_ads_ruby_sdk/utils'

# Modify the request data before it is sent via the SOAP client
BingAdsRubySdk.request_callback.for('hash_params.before_build') << lambda do |args, node, type|
  # Fuzzy matching for elements names
  matcher = type.elements.keys.map { |name| name.tr('_', '').downcase }
  args.each do |h|
    found_at = matcher.index(h[:name].tr('_', '').downcase)
    h[:name] = type.elements.keys[found_at] if found_at
  end

  # Sorts the request data on the wsdl order
  args.sort_by! { |h| type.elements.keys.index(h[:name]) || 1 / 0.0 }
end

# Modify the response data whilst it is being processed by the SOAP client
BingAdsRubySdk.response_callback.for('hash_builder.after_children_hash') << lambda do |hash, node, type|
  hash.keys.each do |k|
    val = hash.delete(k)

    # Convert values of type long to integer.
    # Removes unecessary :long hash key.
    # TODO : use the type from wsdl instead ?
    val = val[:long].map(&:to_i) if val.is_a?(Hash) && val[:long].is_a?(Array)

    # Add the value to the return hash using a symbol as a key instead of the
    # default CamelCase string
    hash[BingAdsRubySdk::Utils.snakize(k).to_sym] = val
  end
end