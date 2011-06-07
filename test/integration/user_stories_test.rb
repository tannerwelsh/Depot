require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products
  
  # Story => 
  # A user goes to the index page. They select a product, adding it to their
  # cart, and check out, filling in their details on the checkout form. When
  # they submit, an order is created containing their information, along with a
  # single line item corresponding to the product they added to their cart.

  test "buying a product" do
    LineItem.delete_all
    Order.delete_all
    ruby_book = products(:ruby)
  
    # Navigate to home page, respond with the "index" template
    get "/"
    assert_response :success
    assert_template "index"
  
    # Add product to line items using xml_http_request method (since we are using AJAX)
    xml_http_request :post, '/line_items', :product_id => ruby_book.id
    assert_response :success
  
    # Check that a cart has been created with the appropriate line item inserted
    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product
  
    # Checkout creates a new order
    get "/orders/new"
    assert_response :success
    assert_template "new"
  
    # User enteres information and posts the order, which empties the cart and redirects to the home page
    post_via_redirect "/orders", :order => { :name => "Dave Thomas", :address => "123 The Street", :email => "dave@example.com", :pay_type => "Check" }
    assert_response :success
    assert_template "index"
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size
  
    # Check database to see if order and line item were created with correct information
    orders = Order.all
    assert_equal 1, orders.size
    order = orders[0]
  
    assert_equal "Dave Thomas", order.name
    assert_equal "123 The Street", order.address
    assert_equal "dave@example.com", order.email
    assert_equal "Check", order.pay_type
  
    assert_equal 1, order.line_items.size
    line_item = order.line_items[0]
    assert_equal ruby_book, line_item.product
  
    # Check that order confirmation email has been sent
    mail = ActionMailer::Base.deliveries.last
    assert_equal ["dave@example.com"], mail.to
    assert_equal 'Sam Ruby <depot@example.com>', mail[:from].value
    assert_equal "Pragmatic Store Order Confirmation", mail.subject
    
    # UNFINISHED
      # Update ship_date for order, and send notification email to buyer
      # ??? Not sure how to update ship_date
      # assert_response :success
      # assert_template "show"
      # assert_equal "2011-01-01", order.ship_date
    
      # Check that shipping confirmation email has been sent
      # mail = ActionMailer::Base.deliveries.last
      # assert_equal ["dave@example.com"], mail.to
      # assert_equal 'Sam Ruby <depot@example.com>', mail[:from].value
      # assert_equal "Pragmatic Store Order Shipped", mail.subject
  end
end
