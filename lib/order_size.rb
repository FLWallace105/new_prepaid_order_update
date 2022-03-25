#order_size.rb
class OrderSize

    def self.add_missing_size(my_json)
        #puts "here --- my_json = #{my_json}"
        leggings = my_json['properties'].select{|x| x['name'] == 'leggings'}
        tops = my_json['properties'].select{|x| x['name'] == 'tops'}
        sports_bra = my_json['properties'].select{|x| x['name'] == 'sports-bra'}
        sports_jacket = my_json['properties'].select{|x| x['name'] == 'sports-jacket'}
        gloves = my_json['properties'].select{|x| x['name'] == 'gloves'}

        #puts "sports_bra = #{sports_bra}"
        #puts "tops = #{tops}"
        #puts "***********"
        #Assuming we always have leggings
        if sports_jacket == [] && tops != []
            my_json['properties'] << { "name" => "sports-jacket", "value" => tops.first['value'].upcase }
        end

        if sports_bra == [] && tops != []
            #puts "FIXING missing sports-bra"
            my_json['properties'] << { "name" => "sports-bra", "value" => tops.first['value'].upcase }
        end

        if tops == [] && sports_bra != []
            my_json['properties'] << { "name" => "tops", "value" => sports_bra.first['value'].upcase }
        end

        if gloves == [] && leggings != []
            temp_leggings = leggings.first['value'].upcase
            temp_gloves = 'M'
            case temp_leggings
            when "XS", "S"
                temp_gloves = 'S'
            when "M"
                temp_gloves = 'M'
            when "L", "XL"
                temp_gloves = 'L'
            else
                temp_gloves = 'M'
            end


            my_json['properties'] << { "name" => "gloves", "value" => temp_gloves }
        end

        return my_json
    end

    def self.add_missing_sub_size(my_json)
        leggings = my_json.select{|x| x['name'] == 'leggings'}
        tops = my_json.select{|x| x['name'] == 'tops'}
        sports_bra = my_json.select{|x| x['name'] == 'sports-bra'}
        sports_jacket = my_json.select{|x| x['name'] == 'sports-jacket'}

        #puts "sports_bra = #{sports_bra}"
        #puts "tops = #{tops}"
        #puts "***********"
        #Assuming we always have leggings
        if sports_jacket == [] && tops != []
            my_json << { "name" => "sports-jacket", "value" => tops.first['value'].upcase }
        end

        if sports_bra == [] && tops != []
            #puts "FIXING missing sports-bra"
            my_json << { "name" => "sports-bra", "value" => tops.first['value'].upcase }
        end

        if tops == [] && sports_bra != []
            my_json << { "name" => "tops", "value" => sports_bra.first['value'].upcase }
        end

        return my_json


    end

end