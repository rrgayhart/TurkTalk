require 'mturk'
require 'digest/sha2'
class MturkService
  attr_reader :mturk, :host

  def initialize(host=:Sandbox)
    @host = host
    @mturk = Amazon::WebServices::MechanicalTurkRequester.new :Host => host, :AWSAccessKeyId => ENV['MTURK_ACCESS_KEY_ID'], :AWSAccessKey => ENV['MTURK_SECRET_ACCESS_KEY']
  end

  def check_funds
    mturk.availableFunds
  end

  def get_contact_information(num = 1, reward = 0.01)
    options = {
      title: "Find Contact Email",
      desc: "Based on the contact information, provide contact information for a person.",
      keywords: "contact, email",
      num: num,
      reward: reward
    }
    locals = {
      question_text: 'Email for contact?'
    }
    partial = 'mturk_questions/basic_hit'
    create_new_hit(options, locals, partial)
  end

  def create_new_hit(options, locals, partial)
    title = options[:title]
    desc = options[:desc]
    keywords = options[:keywords]
    numAssignments = options[:num]
    rewardAmount = options[:reward]

    question = ApplicationController.new.render_to_string(partial: partial, locals: locals)

    result = mturk.createHIT( :Title => title,
                              :Description => desc,
                              :MaxAssignments => numAssignments,
                              :Reward => { :Amount => rewardAmount, :CurrencyCode => 'USD' },
                              :Question => question,
                              :Keywords => keywords )

    puts "Created HIT: #{result[:HITId]}"
    puts "HIT Location: #{getHITUrl( result[:HITTypeId] )}"
    return result
  end

  private

  def getHITUrl( hitTypeId )
    if host === :Production
      "http://mturk.com/mturk/preview?groupId=#{hitTypeId}"
    else
      "http://workersandbox.mturk.com/mturk/preview?groupId=#{hitTypeId}"   # Sandbox Url
    end

  end

end
