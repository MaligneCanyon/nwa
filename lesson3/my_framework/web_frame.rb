# web_frame.rb

private

# encapsulate the creation and organization of the response
def response(status, headers, body = '')
  body = yield if block_given?
  [status, headers, [body]]
end
# def response(status, headers, body = [])
#   body = [yield if block_given?]
#   [status, headers, body]
# end

# create an all-text str for the response body
# def erb(filename) # filename is passed in as a sym
#   template = File.read("views/#{filename}.erb")
#   ERB.new(template).result
# end
def erb(filename, local = {})
  b = binding # tracks 'local' (and specifically 'local[:message]')
  message = local[:message]
  template = File.read("views/#{filename}.erb")
  ERB.new(template).result(b)
end
