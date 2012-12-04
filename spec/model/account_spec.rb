require 'spec_helper'

describe Libertree::Model::Account do
  before :each do
    @account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
    @member = @account.member
  end

  describe '#delete_cascade' do
    context 'given an account with some posts and other entities' do
      before :each do
        other_account = Libertree::Model::Account.create( FactoryGirl.attributes_for(:account) )
        other_member = other_account.member

        post1 = Libertree::Model::Post.create(
          FactoryGirl.attributes_for( :post, member_id: @member.id, text: 'first post' )
        )
        post2 = Libertree::Model::Post.create(
          FactoryGirl.attributes_for( :post, member_id: other_member.id, text: 'second post' )
        )

        comment1 = Libertree::Model::Comment.create(
          FactoryGirl.attributes_for( :comment, member_id: @member.id, post_id: post2.id, text: 'first comment' )
        )
        comment2 = Libertree::Model::Comment.create(
          FactoryGirl.attributes_for( :comment, member_id: other_member.id, post_id: post2.id, text: 'second comment' )
        )

        @post1_id = post1.id
        @post2_id = post2.id
        @comment1_id = comment1.id
        @comment2_id = comment2.id
        @member_id = @member.id
        @account_id = @account.id
      end

      it 'deletes the account and all subordinate entities belonging to the account, but not entities not belonging to the account' do
        Libertree::Model::Post[@post1_id].should_not be_nil
        Libertree::Model::Post[@post2_id].should_not be_nil
        Libertree::Model::Comment[@comment1_id].should_not be_nil
        Libertree::Model::Comment[@comment2_id].should_not be_nil
        Libertree::Model::Member[@member_id].should_not be_nil
        Libertree::Model::Account[@account_id].should_not be_nil

        @account.delete_cascade

        Libertree::Model::Post[@post1_id].should be_nil
        Libertree::Model::Post[@post2_id].should_not be_nil
        Libertree::Model::Comment[@comment1_id].should be_nil
        Libertree::Model::Comment[@comment2_id].should_not be_nil
        Libertree::Model::Member[@member_id].should be_nil
        Libertree::Model::Account[@account_id].should be_nil
      end

      context 'given a problem in account deletion' do
        before :each do
          class Libertree::TestException < StandardError
          end

          class Libertree::Model::Account
            alias :old_delete :delete
            def delete
              raise Libertree::TestException.new('force failure')
            end
          end
        end

        after :each do
          class Libertree::Model::Account
            def delete
              self.old_delete
            end
          end
        end

        it "deletes the account's subordinate entities atomically (never partially)" do
          Libertree::Model::Post[@post1_id].should_not be_nil
          Libertree::Model::Post[@post2_id].should_not be_nil
          Libertree::Model::Comment[@comment1_id].should_not be_nil
          Libertree::Model::Comment[@comment2_id].should_not be_nil
          Libertree::Model::Member[@member_id].should_not be_nil
          Libertree::Model::Account[@account_id].should_not be_nil

          expect {
            @account.delete_cascade
          }.to raise_exception(Libertree::TestException)

          Libertree::Model::Post[@post1_id].should_not be_nil
          Libertree::Model::Post[@post2_id].should_not be_nil
          Libertree::Model::Comment[@comment1_id].should_not be_nil
          Libertree::Model::Comment[@comment2_id].should_not be_nil
          Libertree::Model::Member[@member_id].should_not be_nil
          Libertree::Model::Account[@account_id].should_not be_nil
        end
      end
    end
  end
end
