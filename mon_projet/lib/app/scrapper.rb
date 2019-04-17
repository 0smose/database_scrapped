require 'nokogiri'
require 'open-uri'
require 'json'
require "google_drive"
require 'csv'


class Scrapper

	def cities_hash
	# On va chercher la page des mairies
	page = Nokogiri::HTML(open("http://annuaire-des-mairies.com/val-d-oise.html"))

	# On crée un nouveau hash pour stocker les villes et les liens
	@cities = Hash.new
	
	# On détermine le chemin des liens avec le xpath
	page.xpath("//a[@class='lientxt']").each do |ville|
		@cities[ville.text] = ville['href'].gsub(/^[.]/, 'http://annuaire-des-mairies.com') # On rajoute le début de l'url avec gsub.
	end
	#puts @cities
end

# On crée notre méthode pour scrapper les emails avec le bon xpath
def get_mail(turl)
	page = Nokogiri::HTML(open(turl))
	page.xpath("//html/body/div/main/section[2]/div/table/tbody/tr[4]/td[2]").each do |email|
		return email.text
	end
end

def global
	@global_array = [] # On crée un array global pour notre résultat final

	@cities.each do |cle, valeur| # On crée un hash avec la clé et la valeur qu'on injecte dans notre global_array
		new_hash = Hash.new 
		new_hash[cle] = get_mail(valeur)
		@global_array << new_hash
	end

	# On affiche notre résultat final
	puts @global_array
end

# Perform pour le kiff
def perform # ici on appelle les méthodes pour scrap et pour stocker les data. 3 méthodes
									# pour stock, soit en JSON, soit en spreadsheet google, soit en csv.
	cities_hash
	global
	#save_as_JSON
	#save_as_spreadsheet
	save_as_csv
	# Requis pour le spec
	$spec_global_array = @global_array
end

def save_as_JSON # on stocke tout dans un new hash
	my_new_hash = Hash.new
	@global_array.each do |hash|
		hash.each do |city, mail|
			my_new_hash[city] = mail
		end
	end
	File.open("db/emails.json","w") do |f|
		f.write(JSON.pretty_generate(my_new_hash))
	end
end

def save_as_spreadsheet
	session = GoogleDrive::Session.from_config("config.json")
	ws = session.spreadsheet_by_key("1Hi3gS-oYocPlNlfhPKmafNtnizGgOVrDn60Jppb0wLs").worksheets[0]
 # 1Hi3gS-oYocPlNlfhPKmafNtnizGgOVrDn60Jppb0wLs = la clé du lien de la gSheet
	ws[1,1] = "ville" # 1ere lign 1ere colonne >>> on rentre ville pour donner un titre
	ws[1,2] = "email" # 1ere lign 2eme colonne on rentre email pour donner un titre

	j= 0
	@global_array.each do |i|
		i.each do |k, v| # on entre dans le hash donc double itérateur, key & value
			ws[j + 2 , 1] = k # pour la J ème ligne + 2 (pour laisser une ligne vide), 1ere colonne
												# on donna la valeur de k correspondant aux villes
			ws[j + 2 , 2] = v #même principe pour les emails
		end
		j +=1
	end
	ws.save # sauvegarde des que le programme est terminé
	ws.reload # des que le programme se termine, refresh la page
end

def save_as_csv
	CSV.open("db/emails.csv", "w") do |truc| # "w" pour donner les droits de modifs
		j = 1																	#
		@global_array.each do |i|							#on passe dans l'array, pour chaque i
			i.each do |k, v|										# on passe dans les hashes et on ajoute
				truc << [j, k, v]									#dans l'iterateur truc les itérateurs j K v
			end
				j += 1
		end

	end
end
end

