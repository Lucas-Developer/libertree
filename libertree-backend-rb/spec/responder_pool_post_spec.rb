require 'spec_helper'

describe Libertree::Server::Responder::PoolPost do
  subject {
    Class.new.new
  }

  before :each do
    subject.class.class_eval {
      include Libertree::Server::Responder::Helper
      include Libertree::Server::Responder::PoolPost
    }
  end

  describe 'rsp_pool_post' do
    include_context 'requester in a forest'

    context 'and the responder has a record of the member, the pool and the post' do
      before :each do
        @member = Libertree::Model::Member.create(
          FactoryGirl.attributes_for(:member, :server_id => @requester.id)
        )
        @post = Libertree::Model::Post.create(
          FactoryGirl.attributes_for(:post, member_id: @member.id)
        )
        @pool = Libertree::Model::Pool.create(
          FactoryGirl.attributes_for(:pool, member_id: @member.id, sprung: true)
        )
        subject.instance_variable_set(:@remote_tree, @requester)
      end

      it 'raises MissingParameterError when a parameter is missing or blank' do
        h = {
          'username' => @member.username,
          'pool_id'  => @pool.remote_id,
          'post_id'  => @post.remote_id,
          'origin'   => @post.member.server.domain,
        }

        keys = h.keys
        keys.each do |key|
          h_ = h.reject { |k,v| k == key }
          expect { subject.rsp_pool_post(h_) }.
            to raise_error( Libertree::Server::MissingParameterError )

          h_ = h.dup
          h_[key] = ''
          expect { subject.rsp_pool_post(h_) }.
            to raise_error( Libertree::Server::MissingParameterError )
        end
      end

      it "raises NotFoundError with a member username that isn't found" do
        h = {
          'username' => 'nosuchusername',
          'pool_id'  => 99999999,
          'post_id'  => @post.remote_id,
          'origin'   => @post.member.server.domain,
        }
        expect { subject.rsp_pool_post(h) }.
          to raise_error( Libertree::Server::NotFoundError )
      end

      it "raises NotFoundError with a pool id that isn't found" do
        h = {
          'username' => @member.username,
          'pool_id'  => 99999999,
          'post_id'  => @post.remote_id,
          'origin'   => @post.member.server.domain,
        }
        expect { subject.rsp_pool_post(h) }.
          to raise_error( Libertree::Server::NotFoundError )
      end

      it "raises NotFoundError with a post id that isn't found" do
        h = {
          'username' => @member.username,
          'pool_id'  => @pool.remote_id,
          'post_id'  => 99999999,
          'origin'   => @post.member.server.domain,
        }
        expect { subject.rsp_pool_post(h) }.
          to raise_error( Libertree::Server::NotFoundError )
      end

      context 'with valid Like data, and a member that does not belong to the requester' do
        before :each do
          other_server = Libertree::Model::Server.create( FactoryGirl.attributes_for(:server) )
          @member = Libertree::Model::Member.create(
            FactoryGirl.attributes_for(:member, :server_id => other_server.id)
          )
        end

        it 'raises NotFoundError' do
          h = {
            'username' => @member.username,
            'pool_id'  => @pool.remote_id,
            'post_id'  => 99999999,
            'origin'   => @post.member.server.domain,
          }
          expect { subject.rsp_pool_post(h) }.
            to raise_error( Libertree::Server::NotFoundError )
        end
      end

      context 'with valid data, and a post that does not belong to the requester' do
        before :each do
          other_server = Libertree::Model::Server.create( FactoryGirl.attributes_for(:server) )
          member = Libertree::Model::Member.create(
            FactoryGirl.attributes_for(:member, :server_id => other_server.id)
          )
          @post = Libertree::Model::Post.create(
            FactoryGirl.attributes_for(:post, member_id: member.id)
          )
        end

        it 'raises no errors' do
          h = {
            'username' => @member.username,
            'pool_id'  => @pool.remote_id,
            'post_id'  => @post.remote_id,
            'origin'   => @post.member.server.domain,
          }
          expect { subject.rsp_pool_post(h) }.
            not_to raise_error
        end
      end

      it 'raises no errors with valid data' do
        h = {
          'username' => @member.username,
          'pool_id'  => @pool.remote_id,
          'post_id'  => @post.remote_id,
          'origin'   => @post.member.server.domain,
        }
        expect { subject.rsp_pool_post(h) }.
          not_to raise_error
      end
    end
  end
end
