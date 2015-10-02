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

  def write_romance_scene(num = 1, reward = 0.05, scene=nil)
    scene ||= 'Two vampires are standing on the roof of a building, and one is confessing his love to the other.'
    options = {
      title: "Write Paragraph of Romance Novel Content",
      desc: "Given some information, write a paragraph for a scene in a romance novel.",
      keywords: "creative, writing, romance",
      num: num,
      reward: reward
    }
    locals = {
      question_text: 'Please write a paragraph worth of original text describing the following scene of a romance novel:',
      question_scene: scene
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
