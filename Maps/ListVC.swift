//
//  ListVC.swift
//  Maps
//
//  Created by Yagiz Ozturk on 3.06.2022.
//

import UIKit
import CoreData

class ListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableV: UITableView!
    
    var nameArr = [String]()
    var ids = [UUID]()
    var selectedPlaceName = ""
    var selectedPlaceId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableV.delegate = self
        tableV.dataSource = self
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem))
        getData()
        tableV.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("Newlocation"), object: nil)
        tableV.reloadData()
    }
    @objc func getData(){
        print("getdata")
        nameArr = [String]()
        ids = [UUID]()
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appdelegate.persistentContainer.viewContext
        
        let fetchreq = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        fetchreq.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchreq)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject]{
                    
                    if let name = result.value(forKey: "name") as? String {
                        nameArr.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        ids.append(id)
                        
                    }
                }
            }
        }catch{
            print("hata")
        }
        print(nameArr)
        print(ids)
    }
    @objc func addItem() {
        selectedPlaceName = ""
        performSegue(withIdentifier: "tomaps", sender: nil)
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArr.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArr[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPlaceName = nameArr[indexPath.row]
        selectedPlaceId = ids[indexPath.row]
        performSegue(withIdentifier: "tomaps", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tomaps"{
            let destination = segue.destination as! MapsVC
            destination.selectedName = selectedPlaceName
            destination.selectedId = selectedPlaceId
        }
    }
    func tableView(_ tableView: UITableView,commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete {
            
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appdelegate.persistentContainer.viewContext
            
            let fetchreq = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
            let uuidString = ids[indexPath.row].uuidString
            
            print("delete")
            
            fetchreq.predicate = NSPredicate(format: "id = %@", uuidString)
            fetchreq.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchreq)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        
                        if let id = result.value(forKey: "name") as? String{
                            if id == nameArr[indexPath.row] {
                                
                                context.delete(result)
                                nameArr.remove(at: indexPath.row)
                                ids.remove(at: indexPath.row)
                                
                                self.tableV.reloadData()
                                
                                do{
                                    try context.save()
                                }catch{
                                    
                                }
                                break
                            }
                    }
                }
                }
                tableV.reloadData()
            }catch{
                print("hata")
                
            }
            
        }
    }
}
