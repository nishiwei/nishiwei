require 'anemone'
class AnemoneCrawler
	attr_reader :search_results

	@@dealmoon_root='http://www.dealmoon.com'

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
end