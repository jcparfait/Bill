class CocktailsController < ApplicationController
  before_action :set_cocktail, only: [ :show, :edit, :update, :destroy ]

  def index
    @cocktails = current_user.cocktails
  end

  def show
  end

  def new
    @cocktail = Cocktail.new
  end

  def create
    @cocktail = Cocktail.new(cocktail_params)
    @cocktail.user = current_user

    if @cocktail.save
      redirect_to cocktail_path(@cocktail)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cocktail.update(cocktail_params)
      redirect_to cocktail_path(@cocktail)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cocktail.destroy
    redirect_to cocktails_path, status: :see_other
  end

  private

  def set_cocktail
    @cocktail = Cocktail.find(params[:id])
  end

  def cocktail_params
    params.require(:cocktail).permit(:name, :ingredients, :recipe, :mood)
  end
end
