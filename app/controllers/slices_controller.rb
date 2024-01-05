class SlicesController < ApplicationController
  def index
    @slices = Slice.all
  end

  def create

    slice = Slice.create(
      url: params[:url],
      title: params[:title]
    )
    render json: slice

  end

  private

  def slice_params
    params.require(:slice).permit(:title, :url)
  end 
end
