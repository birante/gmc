class MediaController < ApplicationController
  before_action :set_medium, only: %i[ show edit update destroy ]

  # GET /media
  def index
    @media = Medium.all
  end

  # GET /media/1
  def show
  end

  # GET /media/new
  def new
    @medium = Medium.new
  end

  # GET /media/1/edit
  def edit
  end

  # POST /media
  def create
    @medium = Medium.new(medium_params)

    if @medium.save
      redirect_to @medium, notice: "Medium was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /media/1
  def update
    if @medium.update(medium_params)
      redirect_to @medium, notice: "Medium was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /media/1
  def destroy
    @medium.destroy!
    redirect_to media_path, notice: "Medium was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_medium
      @medium = Medium.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def medium_params
      params.expect(medium: [ :filename, :original_name, :file_path, :file_type, :file_size, :mime_type, :uploaded_by_id, :alt_text, :caption, :width, :height ])
    end
end
