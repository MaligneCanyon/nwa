require "bcrypt"

def encrypt_pswd(text_pswd)
  BCrypt::Password.create(text_pswd)
end

encrypted_pswd = encrypt_pswd("secret")
p encrypted_pswd.class
p encrypted_pswd
hsh = { "a" => encrypted_pswd }
p hsh
