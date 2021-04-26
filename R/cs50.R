#install.packages("Rfacebook")
library("Rfacebook")

#temporary token
#https://developers.facebook.com/tools/explorer/
token <- ""

#me <- getUsers("me", token=token)

#page with posts
fb_page <- getPage(page="Airbank", token=token, n=20, reactions = TRUE, api = "v2.9")
fb_page <- getPage(page="Fiobanka", token=token, n=20, reactions = TRUE, api = "v2.9")
fb_page <- getPage(page="ceskasporitelna", token=token, n=20, reactions = TRUE, api = "v2.9")



#connect to mysql
#install.packages("RMySQL")
library(RMySQL)

con <- dbConnect(RMySQL::MySQL(), dbname = "cs50_proj", user='root', password = 'root')

#redesign data frame

####POST###################################################

#new data frame
post<-data.frame(idpost=substr(fb_page$id[],regexpr('_', 
  fb_page$id[])+1,nchar(fb_page$id[])))
#append data frame
post["idbank"] <- fb_page$from_id[]
post["link"] <- fb_page$link[]
post["text"] <- iconv(fb_page$message[],  to="UTF8")
post["cnt_share"] <- fb_page$shares_count[]
post["cnt_comment"] <- fb_page$comments_count[]
post["type"] <- fb_page$type[]
post["createdate"] <- fb_page$created_time[]

#write into db

dbWriteTable(con, "post", post, row.names = FALSE, append = TRUE)

remove(post)

# for each post in fb_page I create fb_post and create new dataframes..
# that I write into my db as tables (mysql)

for (j in 1:length(fb_page$id[])){
  fb_post <- getPost(post=fb_page$id[j], n=2000, token=token, reactions = TRUE, api = "v2.9")
  

  #####COMMENT#########################################################
  
  #new data frame comment
  comment <- data.frame(idpost  = substr(fb_post$post$id[1],regexpr('_', 
                                                                       fb_post$post$id[1])+1,nchar(fb_post$post$id[1])))
  #fill idpost that is the same value for every comment
  for (i in 1:(length(fb_post$comments$from_id[])-1)){
    comment<- rbind(comment, substr(fb_post$post$id[1],regexpr('_', 
                                                                  fb_post$post$id[1])+1,nchar(fb_post$post$id[1])))
  }
  
  #fill other columns
  comment['idcomment']<-substr(fb_post$comments$id[],regexpr('_', 
    fb_post$comments$id[])+1,nchar(fb_post$comments$id[]))
  comment['iduser']<-fb_post$comments$from_id[]
  comment['name_user']<-iconv(fb_post$comments$from_name[],  to="UTF8")
  comment['cnt_like']<-fb_post$comments$likes_count[]
  comment['cnt_comment']<-fb_post$comments$comments_count[]
  comment['text']<-iconv(fb_post$comments$message[],  to="UTF8")
  comment['createdate']<-fb_post$comments$created_time[] 
  #write into db
  dbWriteTable(con, "comment", comment, row.names = FALSE, append = TRUE)
  
  remove(comment)
  
  ###########################REACTION################################

    #new data frame reaction
  reaction <- data.frame(idpost  = substr(fb_post$post$id[1],regexpr('_', 
                                                                        fb_post$post$id[1])+1,nchar(fb_post$post$id[1])))
  #fill idpost that is the same value for every reaction
  for (i in 1:(length(fb_post$reactions$from_id[])-1)){
    reaction<- rbind(reaction, substr(fb_post$post$id[1],regexpr('_', 
                                                                    fb_post$post$id[1])+1,nchar(fb_post$post$id[1])))
  }
  reaction['iduser']<-fb_post$reactions$from_id
  reaction['name_user']<-iconv(fb_post$reactions$from_name,  to="UTF8")
  reaction['type']<-fb_post$reactions$from_type
  #write into db
  dbWriteTable(con, "reaction", reaction, row.names = FALSE, append = TRUE)
  
  remove (reaction)
  
  # see the progress
  print(paste (fb_page$id[j], 'post was processed '))
}
  



