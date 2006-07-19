class DocumentsController < ApplicationController
	layout 'documents', :except => [:auto_complete_for_tags]

  def index
    redirect_to :action => 'manage'
  end
  
  def add
    @document = AudioDocument.new(params[:document])
    if request.post?
      @document.author = Author.find(session[:user])
    	@document.tag_with(params[:labels])
      if @document.save
        flash[:success] = "Votre document a bien été crée"
        redirect_to :action => 'upload', :id => @document
      else
        flash[:failure] = "Votre document n'a pas été crée"
      end
    end
  end
  
  def show 
  	@document = Author.find(session[:user]).documents.find(params[:id])
  	@review = Review.new(params[:review])
  	if request.post?
  		@review.document = @document
  		@review.user = User.find(session[:user])
  		if @review.save
  			flash[:success] = "Votre commentaire a bien été ajouté"
  			redirect_to :action => 'show', :id => @document 
  		else
  			flash[:failure] = "Votre commentaire n'a pas été ajouté"
  		end
    else
    	@review.rating = 3
  	end
  end
    
  def edit
    @document = Author.find(session[:user]).documents.find(params[:id])
    if request.post?
    	@document.tag_with(params[:labels])
      if @document.update_attributes(params[:document])
        flash[:success] = "Votre document a bien été édité"
        redirect_to :action => 'manage'
      else
        flash[:failure] = "Votre document n'a pas été édité"
      end
    end
  end

	def manage
		@pages = Paginator.new(self, Author.find(session[:user]).documents.size, 4, params[:page])
		@document = Author.find(session[:user]).documents.find(:all, :limit => @pages.items_per_page, :offset => @pages.current.offset)
	end
  
  def upload
  	@document = Author.find(session[:user]).documents.find(params[:id])
  	logger.info(@document.inspect)
  	unless @document.upload
	  	@document.upload = Upload.create 
	  	@document.save
	  end
  	
  	if request.post?
  		if params[:mode] == "ftp"
	  			logger.info "ftp upload from #{@document.upload}"
  			unless @document.upload.empty?
	  			upload_file = @document.upload.file
	  		else
	  			flash[:failure] = "Votre fichier n'a pas été trouvé dans le répertoire ftp"
	  			return
	  		end
			else 
				upload_file = params[:document][:file]
			end
			
			begin
				logger.debug "upload file: #{upload_file}"
				@document.upload_file(upload_file)			
			rescue Exception => e
 				logger.error("can't upload #{upload_file}: #{e}")
			end

			if @document.uploaded?
				@document.upload.destroy
  			@document.save
  			flash[:success] = "Votre fichier a bien été déposé"
  			redirect_to :action => 'share', :id => @document
  		else
  			flash[:failure] = "Votre fichier n'a pas été déposé"
  		end
  	end
  end
  
  def download
  	@document = Author.find(session[:user]).documents.find(params[:id])
  	send_file @document.path, :type => @document.format, :filename => @document.filename
  end
  
  def destroy
    Author.find(session[:user]).documents.find(params[:id]).destroy
    redirect_to :action => 'manage'
  end

  def share
  	@document = Author.find(session[:user]).documents.find(params[:id])
	  flash[:warning] = "Votre document n'est lié à aucun fichier" unless @document.uploaded?
	end
	
	def tags
		@document = Author.find(session[:user]).documents.find_by_tag(params[:name])
	end
	
	def auto_complete_for_tags
		@tag = Tag.find(:all, :conditions => ["name ~* ?", params[:labels]])
	end
	
  def listen
  	@document = Author.find(session[:user]).documents.find(params[:id])
	end

end
