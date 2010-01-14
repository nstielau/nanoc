require 'test/helper'

class Nanoc2::NotificationCenterTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_post
    # Set up notification
    Nanoc2::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Post
    @ping_received = false
    Nanoc2::NotificationCenter.post :ping_received
    assert(@ping_received)
  end

  def test_remove
    # Set up notification
    Nanoc2::NotificationCenter.on :ping_received, :test do
      @ping_received = true
    end

    # Remove observer
    Nanoc2::NotificationCenter.remove :ping_received, :test

    # Post
    @ping_received = false
    Nanoc2::NotificationCenter.post :ping_received
    assert(!@ping_received)
  end

end
