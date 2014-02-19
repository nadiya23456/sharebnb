class ListingsController < ApplicationController
  before_filter :require_signed_in, only: [:new, :create]
  before_filter :require_listing_owner, only: [:edit, :update, :destroy]

  def new
    @listing = Listing.new
    3.times { @listing.date_ranges.build }
    render :new
  end

  def create
    @listing = Listing.new(params[:listing])
    @listing.user_id = current_user.id
    date_range_attributes = params[:date_range_attributes].values.reject do |range| 
      range["start_date"].empty? || range["end_date"].empty?
    end
    @listing.date_ranges.new(date_range_attributes)

    if @listing.save
      flash[:success] = "Please add some more information about your listing"
      redirect_to edit_listing_url(@listing)
    else
      @listing.errors.delete(:date_ranges)
      flash.now[:errors] = @listing.errors.messages.values
      @listing.date_ranges.each do |range|
        flash.now[:errors].concat(range.errors.messages.values)
      end
      until @listing.date_ranges.length === 3
        @listing.date_ranges.build
      end
      render :new
    end

  end

  def index
    @listings = Listing.filter(params[:search])
    render :index
  end

  def show
    @listing = Listing.find(params[:id])
    @booking = @listing.bookings.new({start_date: Date.today, end_date: (Date.today + 1.week)}) # add search params
    render :show
  end

  def edit
    @listing = Listing.includes(:date_ranges).find(params[:id])
    until @listing.date_ranges.length >= 3
      @listing.date_ranges.build
    end
    render :edit
  end

  def update
    @listing = Listing.includes(:date_ranges).find(params[:id])
    @date_ranges = @listing.date_ranges.to_a
    @listing.assign_attributes(params[:listing])

    dr_attributes = params[:date_range_attributes].values.reject do |range|
      range["start_date"].empty? || range["end_date"].empty?
    end

    new_drs = []

    dr_attributes.each do |dr_attribute|
      unless dr_attribute[:id].blank?
        date_range = @date_ranges.find { |dr| dr.id == dr_attribute[:id].to_i }
        date_range.assign_attributes(dr_attribute)
      else
        new_drs << @listing.date_ranges.new(dr_attribute)
      end
    end
    
    new_drs.each(&:save)
    @date_ranges.each(&:save)

    if [@listing, new_drs, @date_ranges].flatten.all?(&:valid?)
      @listing.save
      redirect_to @listing
      
    else
      @listing.errors.delete(:date_ranges)
      flash.now[:errors] = @listing.errors.messages.values
      new_drs.concat(@date_ranges).each do |range|
        flash.now[:errors].concat(range.errors.messages.values)
      end
      flash.now[:errors].uniq!
      until @listing.date_ranges.length >= 3
        @listing.date_ranges.build
      end
      render :edit      
    end
    
  end

  def destroy
    @listing.destroy
    redirect_to root_url # change to dashboard
  end

  def calendar
    @listing = Listing.includes(:date_ranges).find(params[:id])
  end
end