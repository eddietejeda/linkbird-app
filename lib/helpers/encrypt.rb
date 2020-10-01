require 'base64'
require 'digest'
require 'openssl'

def get_encryption_key
  ENV.fetch('APP_ENCRYPTION_KEY')
end

def encrypt_data(key, plaintext)
  assert_app_encryption_keys_are_set!
  
  return "" if plaintext.empty?
  
  cipher = OpenSSL::Cipher::AES256.new :CBC
  cipher.encrypt  # set cipher to be encryption mode
  cipher.key = Digest::SHA256.hexdigest(get_encryption_key)[0..31]
  cipher.iv  = Digest::SHA256.hexdigest(key)[0..15]

  encrypted = ''
  encrypted << cipher.update(plaintext)
  encrypted << cipher.final
  Base64.encode64(encrypted).gsub(/\n/, '')
end

def decrypt_data(key, ciphertext)
  assert_app_encryption_keys_are_set!
  
  return "" if ciphertext.empty?
  
  decipher = OpenSSL::Cipher::AES256.new :CBC
  decipher.decrypt
  decipher.key = Digest::SHA256.hexdigest(get_encryption_key)[0..31]
  decipher.iv = Digest::SHA256.hexdigest(key)[0..15]

  secretdata = Base64::decode64(ciphertext)
  decipher.update(secretdata) + decipher.final
end


def rotate_keys
  
end

def assert_app_encryption_keys_are_set!
  if !get_encryption_key || get_encryption_key.length != 32
    raise "You need to set enviroment variable APP_ENCRYPTION_KEY=<32 bytes>"
  end
end
