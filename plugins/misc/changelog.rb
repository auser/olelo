author      'Daniel Mendler'
description 'RSS Changelogs'
require 'rss/maker'

class Wiki::Application
  after :head do
    if @resource && !@resource.new?
      %{<link rel="alternate" href="/changelog.atom" type="application/atom+xml" title="Sitewide Atom Changelog"/>
        <link rel="alternate" href="#{(@resource.path/'changelog.atom').urlpath}" type="application/atom+xml" title="Atom Changelog"/>
        <link rel="alternate" href="/changelog.rss" type="application/rss+xml" title="Sitewide RSS Changelog"/>
        <link rel="alternate" href="#{(@resource.path/'changelog.rss').urlpath}" type="application/rss+xml" title="RSS Changelog"/>}.unindent
    end
  end

  get '/changelog.:format', '/:path/changelog.:format', :format => /rss|atom/  do
    resource = Resource.find!(params[:path])
    cache_control :etag => resource.version, :last_modified => resource.version.date

    content_type "application/#{params[:format]}+xml", :charset => 'utf-8'
    prefix = request.scheme + '://' +  request.host + ':' + request.port.to_s + '/'

    content = RSS::Maker.make(params[:format] == 'rss' ? '2.0' : 'atom') do |feed|
      feed.channel.generator = 'Git-Wiki'
      feed.channel.title = Config.title
      feed.channel.link = prefix + resource.path
      feed.channel.description = Config.title + ' Changelog'
      feed.channel.id = prefix + resource.path # atom
      feed.channel.updated = Time.now
      feed.channel.author = 'Git-Wiki'
      feed.items.do_sort = true
      resource.history.each do |version|
        i = feed.items.new_item
        i.title = version.comment
        i.link = prefix + 'changes'/version
        i.date = version.date
        i.dc_creator = version.author.name
      end
    end
    content.to_s
  end
end
