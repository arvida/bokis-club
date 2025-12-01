class ChangeLocaleNullFalseOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :locale, false
  end
end
