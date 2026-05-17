module ApplicationHelper
  def env(key)
    ENV[key.to_s]
  end

  def assets_path
    ENV['STATIC_URL']
  end
end
