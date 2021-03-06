require 'test_helper'
require 'digest/sha1'

class DatabaseAuthenticatableTest < ActiveSupport::TestCase
  test 'should respond to password and password confirmation' do
    user = new_user
    assert user.respond_to?(:password)
    assert user.respond_to?(:password_confirmation)
  end

  test 'should generate encrypted password while setting password' do
    user = new_user
    assert_present user.encrypted_password
  end

  test 'should not generate encrypted password if password is blank' do
    assert_blank new_user(:password => nil).encrypted_password
    assert_blank new_user(:password => '').encrypted_password
  end

  test 'should encrypt password again if password has changed' do
    user = create_user
    encrypted_password = user.encrypted_password
    user.password = user.password_confirmation = 'new_password'
    user.save!
    assert_not_equal encrypted_password, user.encrypted_password
  end

  test 'should test for a valid password' do
    user = create_user
    assert user.valid_password?('123456')
    assert_not user.valid_password?('654321')
  end

  test 'should respond to current password' do
    assert new_user.respond_to?(:current_password)
  end

  test 'should update password with valid current password' do
    user = create_user
    assert user.update_with_password(:current_password => '123456',
      :password => 'pass321', :password_confirmation => 'pass321')
    assert user.reload.valid_password?('pass321')
  end

  test 'should add an error to current password when it is invalid' do
    user = create_user
    assert_not user.update_with_password(:current_password => 'other',
      :password => 'pass321', :password_confirmation => 'pass321')
    assert user.reload.valid_password?('123456')
    assert_match "is invalid", user.errors[:current_password].join
  end

  test 'should add an error to current password when it is blank' do
    user = create_user
    assert_not user.update_with_password(:password => 'pass321',
      :password_confirmation => 'pass321')
    assert user.reload.valid_password?('123456')
    assert_match "can't be blank", user.errors[:current_password].join
  end

  test 'should ignore password and its confirmation if they are blank' do
    user = create_user
    assert user.update_with_password(:current_password => '123456', :email => "new@email.com")
    assert_equal "new@email.com", user.email
  end

  test 'should not update password with invalid confirmation' do
    user = create_user
    assert_not user.update_with_password(:current_password => '123456',
      :password => 'pass321', :password_confirmation => 'other')
    assert user.reload.valid_password?('123456')
  end

  test 'should clean up password fields on failure' do
    user = create_user
    assert_not user.update_with_password(:current_password => '123456',
      :password => 'pass321', :password_confirmation => 'other')
    assert user.password.blank?
    assert user.password_confirmation.blank?
  end
end
