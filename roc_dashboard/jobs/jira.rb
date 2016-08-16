require 'net/http'
require 'json'
require 'time'
require 'open-uri'
require 'cgi'

@info = {}

JIRA_OPENISSUES_CONFIG = {
  jira_url: "https://jira.brandnetworksinc.com",
  username:  "jira-reader",
  password: ENV['JIRA_PASS'],
  issuecount_mapping: {
    'Bugs Created' => "filter=19115",
    'Bugs Closed' => "filter=19112",
    'Issues Opened' => "filter=19113",
    'Issues Closed' => "filter=19114",
    'Blockers' => "filter=19116",
    'RCA Tickets' => "filter=19117"
  }
}

def getNumberOfIssues(url, username, password, jqlString)
  jql = CGI.escape(jqlString)
  uri = URI.parse("#{url}/rest/api/2/search?jql=#{jql}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  request = Net::HTTP::Get.new(uri.request_uri)
  if !username.nil? && !username.empty?
    request.basic_auth(username, password)
  end
  begin
    JSON.parse(http.request(request).body)["total"]
  rescue JSON::ParserError => e
    "Error"
  end
end

def send_info
  if ENV['ENABLE_JIRA'] == 'true'
    @info = {}
    JIRA_OPENISSUES_CONFIG[:issuecount_mapping].each do |mappingName, filter|
      total = getNumberOfIssues(JIRA_OPENISSUES_CONFIG[:jira_url], JIRA_OPENISSUES_CONFIG[:username], JIRA_OPENISSUES_CONFIG[:password], filter)
      @info[mappingName] = total
    end
    send_event('jira-scroll', { scroll_info: @info })
  else
    puts "\e[33mJira is disabled. To enable, set the environment variable 'ENABLE_JIRA' to 'true'\e[0m"
  end
end

  send_info

SCHEDULER.every '60s' do
    send_info
end
