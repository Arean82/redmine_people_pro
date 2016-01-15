# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class PeopleControllerTest < ActionController::TestCase

  fixtures :users
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedminePeople::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_people).directory + '/test/fixtures/',
                            [:departments, :people_information, :custom_fields, :custom_values])

  def setup
    @person = Person.find(4)
    # Remove accesses operations
    Setting.plugin_redmine_people = {}
  end

  def access_message(action)
    "No access for the #{action} action"
  end

  def test_without_authorization
    # Get
    [:index, :show, :new, :edit].each do |action|
      get action, :id => @person.id
      assert_response 302, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      post action, :id => @person.id
      assert_response 302, access_message(action)
    end
  end

  def test_with_deny_user
    @request.session[:user_id] = 2
    # Get
    [:show, :index, :new, :edit].each do |action|
      get action, :id => @person.id
      assert_response 403, access_message(action)
    end

    # Post
    [:update, :destroy, :create].each do |action|
      post action, :id => @person.id
      assert_response 403, access_message(action)
    end
  end

  def test_get_index
    @request.session[:user_id] = 1
    get :index
    assert_response :success
    assert_template :index
    assert_select 'h1 a', 'Redmine Admin'
  end
  def test_get_index_with_filters
    @request.session[:user_id] = 1
    get :index, :group_by => 'department',
        :f => [
         'firstname',
         'lastname',
         'middlename',
         'gender',
         'address',
         'phone',
         'skype',
         'twitter',
         'birthday',
         'job_title',
         'company',
         'appearance_date',
         'department status'],

        :op => { 'firstname' => '=' ,
                 'lastname' => '=',
                 'middlename' => '=',
                 'gender' => '=',
                 'address' => '=',
                 'phone' => '=',
                 'skype' => '=',
                 'twitter' => '=',
                 'birthday' => '=',
                 'job_title' => '=',
                 'company' => '=',
                 'appearance_date' => '=',
                 'department'  => '=',
                 'status'  => '='

          },
        :v => { 'firstname' => ['Redmine'],
                'lastname' => ['Admin'],
                'middlename' => ['Petrovich'],
                'gender' => ['0'],
                'address' => ['Korolevo street'],
                'phone' => ['89125555555'],
                'skype' => ['Flex'],
                'twitter' => ['sky'],
                'birthday' => ['1991-07-19'],
                'job_title' => ['disigner'],
                'company' => ['IBM'],
                'appearance_date' => ['2014-07-20'],
                'department' => ['2'],
                'status' => ['1'],
    }
    assert_response :success
    assert_template :index
    assert_select 'h1 a', 'Redmine Admin'
  end

  def test_get_index_with_tag
    @request.session[:user_id] = 1

    person = Person.find(4)
    person.tag_list = 'Tag1, Tag2'
    person.save

    get :index, {
      :f =>['tags'],
      :op => {'tags' => "="},
      :v => {'tags' => ['Tag1']}
    }

    assert_select 'h1 a', {:count => 0, :text => /Redmine Admin/}
    assert_select 'h1 a', 'Robert Hill'
  end

  def test_get_index_as_table
    @request.session[:user_id] = 1

    get :index, {
      :people_list_style => 'list',
      :f =>['cf_1'],
      :set_filter => '1',
      :op => {'cf_1' => "="},
      :v => {'cf_1' => ['Sitroen']},
      :c => ['firstname', 'cf_1', 'cf_2'] # Show custom field columns
    }
    assert_no_match /Volvo/,  @response.body
    assert_match /Sitroen/,  @response.body
  end

  def test_get_show
    @request.session[:user_id] = 1
    get :show , :id => @person.id
    assert_response :success
    assert_select 'h1', /Robert Hill/
  end

  def test_get_new
    @request.session[:user_id] = 1
    get :new
    assert_response :success
  end

  def test_get_edit
    @request.session[:user_id] = 1
    get :edit , :id => @person.id
    assert_response :success
    assert_select "input[value='Hill']"
  end

  def test_post_create
    @request.session[:user_id] = 1
    post :create,
         :person => {
                    :login => 'login',
                    :password => '12345678',
                    :password_confirmation => '12345678',
                    :firstname => 'Ivan',
                    :lastname => 'Ivanov',
                    :mail => 'ivan@ivanov.com',
                    :information_attributes => {
                      :facebook => 'Facebook',
                      :middlename => 'Ivanovich'
                    },
                    :tag_list => 'Tag1, Tag2'
                   }
    person = Person.last
    assert_redirected_to :action => 'show', :id => person.id
    assert_equal ['ivan@ivanov.com','Ivanovich'], [person.email, person.middlename]
    assert_equal ['Tag1', 'Tag2'], person.tag_list.sort
  end

  def test_put_update
    @request.session[:user_id] = 1
    post :update,
        :id => @person.id,
        :person => {
                     :firstname => 'firstname',
                     :information_attributes => {
                      :facebook => 'Facebook2',
                    }
                   }
    @person.reload
    assert_redirected_to :action => 'show', :id => @person.id
    assert_equal ['firstname','Facebook2'], [@person.firstname, @person.facebook]
  end

  def test_destroy
    @request.session[:user_id] = 1
    post :destroy, :id => 4
    assert_redirected_to :action => 'index'
    assert_raises(ActiveRecord::RecordNotFound) do
      Person.find(4)
    end
  end

  def test_load_tab
    @request.session[:user_id] = @person.id
    xhr :get, :load_tab, :tab_name => 'activity', :partial => 'activity', :id => @person.id
    assert_response :success

    xhr :get, :load_tab, :tab_name => 'files', :partial => 'attachments', :id => @person.id
    assert_response :success

    xhr :get, :load_tab, :tab_name => 'projects', :partial => 'projects', :id => @person.id
    assert_response :success
  end
  def test_autocomplete_tags
    @request.session[:user_id] = 1

    person = Person.find(4)
    person.tag_list = 'Tag1, Tag2'
    person.save

    xhr :get, :autocomplete_tags, :q => 'g1'

    assert_match /[\"Tag1\"]/, response.body
  end

end
