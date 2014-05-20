class Account < ActiveRecord::Base
  has_many :agents

  scope :with_agent_count, -> {
    select('accounts.*, count(agents.id) AS agent_count').
    joins(:agents).group(:id)
  }

  def agent_count
    if count = read_attribute('agent_count')
      count.to_i
    else
      agents.length
    end
  end
end
