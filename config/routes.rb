Nplusone::Application.routes.draw do
  root 'accounts#index'

  get 'includes', to: 'accounts#includes'
  get 'sql',      to: 'accounts#sql'
end
