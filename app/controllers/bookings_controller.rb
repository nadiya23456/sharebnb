class BookingsController < ApplicationController
  
  before_filter :require_signed_in
  before_filter :require_listing_owner, only: [:index]
  
  def create
    @listing = Listing.find(params[:listing_id])
    @booking = @listing.bookings.new(params[:booking])
    @booking.guest_id = current_user.id
    if @booking.save
      flash[:success] = "Your booking has been requested.  The host will review and accept or decline your booking request."
      redirect_to user_trips_url(current_user)
    else
      flash.now[:errors] = @booking.errors.messages.values
      render "listings/show"
    end
  end
  
  def trips
    @bookings = current_user.bookings.where("end_date >= ?", Date.today)
      .order("start_date ASC")
      .includes(:listing)
  end
  
  def index
    @listing = Listing.find(params[:listing_id])
    where_condition = <<-SQL
      listing_id = ? AND status = ? AND cancelled = false AND end_date >= ?
    SQL
    @pending_bookings = Booking.where(where_condition, @listing.id, 0, Date.today)
      .order("start_date ASC")
      .includes(:guest).to_a
    @confirmed_bookings = Booking.where(where_condition, 1, @listing.id, Date.today)
      .order("start_date ASC")
      .includes(:guest).to_a
  end
  
  def accept
    @booking = Booking.find(params[:id])
    @listing = @booking.listing
    @booking.change_status_to(1)
    @booking.overlapping_bookings.each { |other_booking| other_booking.change_status_to(2) }
    flash[:success] = "Booking has been accepted!"
    redirect_to listing_bookings_url(@listing)
  end
  
  def decline
    @booking = Booking.find(params[:id])
    @listing = @booking.listing
    @booking.change_status_to(2)
    flash[:success] = "Booking has been declined!"
    redirect_to listing_bookings_url(@listing)
  end
  
  def cancel
    @booking = Booking.find(params[:id])
    @listing = @booking.listing
    @booking.cancel!
    flash[:success] = "Booking has been cancelled!"
    redirect_to :back
  end
  
end
