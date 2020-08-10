class ScriptManager::Hasher
  def self.hash!(content)
    Digest::MD5.hexdigest(content)
  end
end