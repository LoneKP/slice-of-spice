class AddFallbackAvatarToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :fallback_avatar, :string
  end
end
