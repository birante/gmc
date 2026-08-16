class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @post = Post.friendly.find(params[:post_id])
    return redirect_to @post, alert: "Comments are closed on this post." unless @post.allow_comments?
    @comment = @post.comments.new(comment_params.merge(user: current_user,
                                                       ip_address: request.remote_ip,
                                                       user_agent: request.user_agent))
    # Auto-approve moderators; hold others for review
    @comment.status = current_user.can_moderate? ? :approved : :pending
    if @comment.save
      redirect_to @post, notice: current_user.can_moderate? ? "Comment posted." : "Comment submitted for moderation."
    else
      redirect_to @post, alert: "Comment invalid."
    end
  end

  def moderate
    authorize Comment
    @comment = Comment.find(params[:id])
    @comment.update(status: params[:status])
    redirect_back fallback_location: post_path(@comment.post_id), notice: "Comment #{params[:status]}."
  end

  private
  def comment_params = params.require(:comment).permit(:content, :parent_id)
end
