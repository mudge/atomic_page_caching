module AtomicPages
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def atomically_caches_page(*actions)
      return unless perform_caching
      options = actions.extract_options!
      after_filter({:only => actions}.merge(options)) { |c| c.atomically_cache_page }
    end

    def atomically_cache_page(content, path)
      return unless perform_caching

      tmp_page_cache_path = "#{page_cache_path(path)}.tmp"
      real_page_cache_path = page_cache_path(path)

      benchmark "Atomically cached page: #{page_cache_file(path)}" do
        FileUtils.makedirs(File.dirname(page_cache_path(path)))
        File.open(tmp_page_cache_path, "wb+") { |f| f.write(content) }
        FileUtils.mv(tmp_page_cache_path, real_page_cache_path)
      end
    end
  end

  def atomically_cache_page(content = nil, options = nil)
    return unless perform_caching && caching_allowed

    path = case options
      when Hash
        url_for(options.merge(:only_path => true, :skip_relative_url_root => true, :format => params[:format]))
      when String
        options
      else
        request.path
    end

    self.class.atomically_cache_page(content || response.body, path)
  end
end
