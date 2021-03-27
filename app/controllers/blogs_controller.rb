class BlogsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :edit, :publish, :unpublish, :update, :destroy]
  before_action :set_blog, only: %i[ show edit update destroy publish unpublish ]

  # GET /blogs or /blogs.json
  def index
  end
  
  def table
    if user_signed_in? && current_user.admin?
      @blogs = Blog.all
    else
      @blogs = Blog.where_not(published_at: nil)
    end
    respond_to do |format|
      format.json
    end
  end

  # GET /blogs/1 or /blogs/1.json
  def show
    renderer = Redcarpet::Render::HTML.new(:link_attributes => Hash["target" => "_blank"], hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    @wiki = markdown.render(@blog.post)
    
    respond_to_format
  end

  # GET /blogs/new
  def new
    @blog = Blog.new
  end

  # GET /blogs/1/edit
  def edit
  end

  # POST /blogs or /blogs.json
  def create
    @blog = Blog.new(blog_params)

    respond_to do |format|
      if @blog.save
        format.html { redirect_to @blog, notice: "Blog was successfully created." }
        format.json { render :show, status: :created, location: @blog }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blogs/1 or /blogs/1.json
  def update
    respond_to do |format|
      if @blog.update(blog_params)
        format.html { redirect_to @blog, notice: "Blog was successfully updated." }
        format.json { render :show, status: :ok, location: @blog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # GET /blogs/1/publish
  def publish
    @blog.published_at = DateTime.now
    @blog.user = current_user
    respond_to do |format|
      if @blog.save
        format.html { redirect_to @blog, notice: "Blog was successfully updated." }
        format.json { render :show, status: :ok, location: @blog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # GET /blogs/1/unpublish
  def unpublish
    @blog.published_at = nil
    respond_to do |format|
      if @blog.save
        format.html { redirect_to @blog, notice: "Blog was successfully updated." }
        format.json { render :show, status: :ok, location: @blog }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @blog.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1 or /blogs/1.json
  def destroy
    @blog.destroy
    respond_to do |format|
      format.html { redirect_to blogs_url, notice: "Blog was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_blog
      @blog = Blog.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def blog_params
      params.fetch(:blog, {})
    end
    
    def blog_params
      params.require(:blog).permit(:title, :post)
    end
end
