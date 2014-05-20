# Query Optimization (N+1 Queries)

An N+1 query is any query that spawns an additional query for each result of the original query.
 
- 1: The initial query
- N: The number of additional queries as a result of the first one

## The Setup

Imagine you are working for a company that monitors application performance. You've written an agent that can collect performance data and everything is working great. However, you keep getting interrupted by people asking you to run a report to tell them how many agents each account has deployed.

In order to save yourself some time, you decide to provide your coworkers with a list of account information they can easily access. Something like the following:

| Name       | # of Agents |
| ---------- | -----------:|
| Startup 1  | 4           |
| Startup 2  | 10          |
| Startup 3  | 7           |
| Startup 4  | 8           |

So you spin up a rails application and write the following code:

```ruby
# app/models/account.rb
class Account < ActiveRecord::Base
  has_many :agents
end

# app/models/agent.rb
class Agent < ActiveRecord::Base
  belongs_to :account
end

# app/controllers/accounts_controller.rb
class AccountsController < ApplicationController
  def index
    @accounts = Account.all
  end
end
```

```erb
<%# app/views/accounts/index.html.erb %>
<table>
  <tr>
    <th>Name</th>
    <th># of Applications</th>
  </tr>
  <% @accounts.each do |account| %>
    <td><%= account.name %></td>
    <td><%= account.agents.count %>
  <% end %>
</table>
```

## The N + 1

Before deploying your new code to production, you fire up your browser and visit the page. The page loads! Everything seems great, until you look at the logs. That is where you notice the N+1 query that has just been created.

```bash
# logs/development.rb
Started GET "/accounts" for 127.0.0.1 at 2014-05-14 20:37:44 -0700
Processing by AccountsController#index as HTML
  Account Load (0.5ms)  SELECT `accounts`.* FROM `accounts`
   (0.3ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 1
   (0.3ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 2
   (0.2ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 4
   (0.2ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 5
  Rendered accounts/index.html.erb within layouts/application (5.7ms)
Completed 200 OK in 10ms (Views: 7.6ms | ActiveRecord: 1.6ms)
```

In the above log you can see the N+1 query:
- 1: The initial query

        Account Load (0.5ms)  SELECT `accounts`.* FROM `accounts`

- N: The number of additional queries as a result of the first one. The first query returned a total of 4 accounts. As we iterated over those four accounts, we executed an additional query. So we ended up with a total of 5 queries. N (4 accounts) + 1 (query to get the accounts) = 5.

        (0.3ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 1
        (0.3ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 2
        (0.2ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 4
        (0.2ms)  SELECT COUNT(*) FROM `agents` WHERE `agents`.`account_id` = 5
        
### These queries ran really fast, is this really a performance problem?

The additional n queries did execute incredibly fast. Less than a millisecond each. However, in a production environment, you will have a bit more latency than local dev. Let's say that causes each query to execute in 1ms. Now imagine the list contains 100 accounts. It would then take 100ms to load the number of agents, which is a pretty substantial amount of time to render just one column in a table.

