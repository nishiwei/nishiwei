require 'anemone'
class AnemoneCrawler
	attr_reader :search_results, :crawled_pages, :leaf_path_counting

	@@dealmoon_root='http://www.dealmoon.com'
	@@ignore_elements = ['script','style','meta','comment']

	def crawl_dealmoon_search_result(keyword_string)
		if keyword_string.is_a? String
		search_param = "q=#{keyword_string.strip.gsub(/\s+/, '+')}"
		page_docs = [] 
		@search_results = []
		Anemone.crawl("#{@@dealmoon_root}/search?#{search_param}", depth_limit: 0) do |core|
			core.on_every_page do |page|
				page_docs.push page.doc
				result_list = page.doc.xpath('//div[@class="ml"]/div[@class="mc"]/div[@class="mlist"]') 
				result_list.each do |result|
					expire = result.xpath('.//h2/span//text()').text.strip
					title = result.xpath('.//h2//a').text.strip
					table = result.xpath('.//table//td//text()').text.strip
					@search_results.push({expire: expire, title: title, table: table})
				end
			end
		end
		page_docs
		else
			pp 'Usage:'
		end
	end

	def crawl_page(url,flush=true)
		@crawled_pages = [] if flush
		Anemone.crawl(url, depth_limit: 0) do |core|
			core.on_every_page do |page|
				@crawled_pages ||= []
				@crawled_pages.push page
			end
		end
	end

	def search_on_dealmoon(keyword_string)
		search_param = "q=#{keyword_string.strip.gsub(/\s+/, '+')}"
		crawl_page "#{@@dealmoon_root}/search?#{search_param}"
	end

	def start_dom_traversal
		@leaf_path_counting = {}
		root = @crawled_pages.first.doc.root
		dom_traversal [], [root]
		@leaf_path_counting=@leaf_path_counting.sort_by{|a,b| (b.map(&:length).reduce(:+)||0)}
	end

	def digging_page url
		crawl_page "http://#{url}", true
	end

	def dom_traversal dom_array, nodes
		nodes.each do |node|
			next if @@ignore_elements.include? node.name
			node_identifier = node.attr('class')
			# class_name = node.attr('class')
			# element = node.name
			# node_identifier = "#{element}#{"##{id}" if id}#{".#{class_name}" if class_name}"
			if node.children.any?
				new_dom_array = Array.new dom_array
				new_dom_array.push node_identifier if node_identifier
				dom_traversal new_dom_array, node.children
			elsif text=node.text
				text.strip!
				@leaf_path_counting[dom_array] ||= []
				@leaf_path_counting[dom_array].push text if text.present?
			end
		end
	end

	def run url
		digging_page url
		start_dom_traversal
	end
end