class AccountsController < ApplicationController

  def index
    @accounts = Account.limit(50)
  end

  def includes
    @accounts = Account.includes(:agents).limit(50)
    render :index
  end

  def sql
    @accounts = Account.with_agent_count.limit(50)
    render :index
  end

end
